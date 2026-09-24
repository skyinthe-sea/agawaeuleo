import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/utils/hangul_typing.dart';
import '../../../widgets/surfaces/clay_sheen.dart';
import '../../../widgets/symptom/symptom_illustration.dart';
import '../../../widgets/symptom/symptom_tone.dart';

/// 온보딩 스테이지의 "떠 있는 UI 조각" — 실제 앱 화면(검색·제품 랭킹·병원 신호)을
/// 축소한 미리보기. 추상 아이콘 대신 제품의 진짜 모습을 보여 주는 게 목적이라
/// 표면·배지·타이포는 본 화면 컴포넌트의 토큰 문법을 그대로 따른다.
///
/// DESIGN v3 "몽글 클레이" — 둥근(lg) 크림 카드 + 넓게 퍼지는 장밋빛 그림자(헤어라인
/// 없음), 배지·라벨은 흰 테두리 스티커 칩, 제목은 주아체, 썸네일은 동그란 톤 워시
/// 쿠션 위 클레이 일러스트, 채운 알약 버튼은 클레이 광택 + 자기 색 그림자.
///
/// 전부 장식(스테이지가 ExcludeSemantics로 감싼다). [active]는 해당 장면이
/// 화면에 안착했는지 — 타이핑·스탬프·신호 내려앉기 같은 1회성 마이크로 인터랙션을
/// 그때 재생하고, reduce-motion이면 완료 상태로 바로 그린다.
class OnboardingFloatSurface extends StatelessWidget {
  const OnboardingFloatSurface({
    required this.child,
    super.key,
    this.width,
    this.borderRadius = AppRadius.brLg,
    this.padding = const EdgeInsets.all(AppSpacing.x12),
  });

  final Widget child;
  final double? width;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.paperRaised,
        borderRadius: borderRadius,
        // DESIGN v3 §5.1 — 헤어라인 대신 넓게 퍼지는 장밋빛 그림자로 떠 보이게(오버레이 e4).
        boxShadow: context.shadows.e4,
      ),
      child: child,
    );
  }
}

/// ① 검색 바 — "배앓이"를 실제 한글 IME처럼 자모 조합 순서로 타이핑한다.
class OnboardingSearchPill extends StatefulWidget {
  const OnboardingSearchPill({required this.active, super.key});

  final bool active;

  /// ㅂ → 배 → 뱅 → 배아 → … 조합 중 받침이 다음 음절로 넘어가는 순간까지 재현.
  static final List<String> typingSteps = hangulTypingSteps('배앓이');

  @override
  State<OnboardingSearchPill> createState() => _OnboardingSearchPillState();
}

class _OnboardingSearchPillState extends State<OnboardingSearchPill>
    with TickerProviderStateMixin {
  // reduce-motion에서도 dispose가 안전하도록 initState 즉시 생성(지연 초기화 금지).
  late final AnimationController _typing = AnimationController(vsync: this);

  /// 자모 8타 입력 시간.
  static const Duration _typeTime = Duration(milliseconds: 980);

  /// 입력 전 대기 — 첫 진입은 스테이지 등장(카드 착지)을 기다리고, 다시 돌아왔을
  /// 때는 짧게 한 박자만 쉰다.
  static const Duration _firstDelay = Duration(milliseconds: 720);
  static const Duration _revisitDelay = Duration(milliseconds: 220);

  /// 전체 컨트롤러 구간 중 대기가 차지하는 비율(재생마다 갱신).
  double _typeStart = 0;
  bool _playedOnce = false;
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    _typing.value = 1;
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(OnboardingSearchPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
    if (!widget.active && oldWidget.active) _blink.stop();
  }

  void _play() {
    if (!mounted || context.reduceMotion) return;
    final delay = _playedOnce ? _revisitDelay : _firstDelay;
    _playedOnce = true;
    final total = delay + _typeTime;
    _typeStart = delay.inMilliseconds / total.inMilliseconds;
    _typing
      ..duration = total
      ..forward(from: 0);
    _blink.repeat();
  }

  @override
  void dispose() {
    _typing.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final steps = OnboardingSearchPill.typingSteps;

    return OnboardingFloatSurface(
      width: 204,
      borderRadius: AppRadius.brFull,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x8,
        AppSpacing.x8,
        AppSpacing.x8,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: colors.accent),
          const SizedBox(width: AppSpacing.x8),
          AnimatedBuilder(
            animation: _typing,
            builder: (context, _) {
              final typed = Interval(_typeStart, 1).transform(_typing.value);
              final count = (typed * steps.length).ceil().clamp(
                0,
                steps.length,
              );
              return Text(
                count == 0 ? '' : steps[count - 1],
                style: texts.heading.copyWith(color: colors.ink900),
                maxLines: 1,
              );
            },
          ),
          const SizedBox(width: AppSpacing.x2),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _blink,
              curve: const Threshold(0.5),
            ),
            child: Container(
              width: 2,
              height: 18,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: AppRadius.brFull,
              ),
            ),
          ),
          const Spacer(),
          // 젤리 버튼 — accent 면 + 클레이 광택 + 자기 색 그림자.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: ClaySheen.gradient(context, colors.accentFill),
              shape: BoxShape.circle,
              boxShadow: ClaySheen.toneShadow(context, colors.accentFill),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: colors.paperRaised,
            ),
          ),
        ],
      ),
    );
  }
}

/// ① 검색 결과 행 — 홈 카드와 같은 증상 일러스트(배앓이) + 한 줄 설명.
class OnboardingResultCard extends StatelessWidget {
  const OnboardingResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return OnboardingFloatSurface(
      width: 214,
      child: Row(
        children: [
          _WashCushion(
            size: 48,
            wash: SymptomTone.resolve(context, 'tummy_pain').wash,
            child: SymptomIllustrations.has('tummy_pain')
                ? const SymptomIllustration(
                    illustrationKey: 'tummy_pain',
                    size: 48,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '배앓이',
                  style: texts.heading.copyWith(color: colors.ink900),
                ),
                Text(
                  '영아산통·가스',
                  style: texts.caption.copyWith(color: colors.ink500),
                ),
              ],
            ),
          ),
          const _RoundGlyph(icon: Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// ② "배앓이 맞춤 추천" 스티커 칩 — 버터 블롭 위에 붙인 딸기 스티커.
class OnboardingRecommendChip extends StatelessWidget {
  const OnboardingRecommendChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 스티커 자체 그림자(e1)는 카드 안 배지용이라, 무대 위에 떠 있는 만큼 e4를 덧댄다.
    // 무대의 한쪽 기준 Positioned는 가로 제약이 없다 — 칩 안의 Flexible 라벨이 폭을
    // 알 수 있게 내용 폭으로 묶는다(IntrinsicWidth).
    return IntrinsicWidth(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.brFull,
          boxShadow: context.shadows.e4,
        ),
        child: StickerChip(
          label: '배앓이 맞춤 추천',
          leading: Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: colors.amber,
          ),
          wash: colors.accentWash,
          fg: colors.accent,
        ),
      ),
    );
  }
}

/// ② 제품 랭킹 보드 미리보기 — DESIGN v2 §7.3-6 "에디토리얼 랭킹 보드" 축약판
/// (v3 외형: 1위 버터 리본 스티커 + 동그란 순위 스티커). 장면이 안착하면 1위 배지가
/// 스티커를 붙이듯 톡 앉는다.
class OnboardingBestPickCard extends StatefulWidget {
  const OnboardingBestPickCard({required this.active, super.key});

  final bool active;

  @override
  State<OnboardingBestPickCard> createState() => _OnboardingBestPickCardState();
}

class _OnboardingBestPickCardState extends State<OnboardingBestPickCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void initState() {
    super.initState();
    _stamp.value = 1;
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(OnboardingBestPickCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  void _play() {
    if (!mounted || context.reduceMotion) return;
    _stamp.forward(from: 0);
  }

  @override
  void dispose() {
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    final badge = AnimatedBuilder(
      animation: _stamp,
      builder: (context, child) {
        final v = _stamp.value;
        final settle = Curves.easeOutBack.transform(
          const Interval(0.15, 1).transform(v),
        );
        return Opacity(
          opacity: const Interval(0, 0.35).transform(v),
          child: Transform.scale(scale: 1.7 - 0.7 * settle, child: child),
        );
      },
      child: _NumberSticker(
        number: 1,
        fg: colors.amber,
        wash: colors.amberWash,
      ),
    );

    return OnboardingFloatSurface(
      width: 222,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              badge,
              const SizedBox(width: AppSpacing.x8),
              // 1위 리본 — 버터 스티커(DESIGN v3 §6 제품 랭킹 보드).
              Flexible(
                child: StickerChip(
                  label: 'BEST PICK',
                  icon: Icons.workspace_premium_rounded,
                  wash: colors.amberWash,
                  fg: colors.amber,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Row(
            children: [
              _WashCushion(
                size: 44,
                wash: SymptomTone.resolve(context, 'burp').wash,
                child: SymptomIllustrations.has('burp')
                    ? const SymptomIllustration(
                        illustrationKey: 'burp',
                        size: 44,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '안티콜릭 젖병',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _jua(texts.bodyL).copyWith(color: colors.ink900),
                    ),
                    Text(
                      '공기 유입을 줄인 구조',
                      style: texts.caption.copyWith(color: colors.ink500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
            child: Divider(height: 1, thickness: 1, color: colors.line),
          ),
          Row(
            children: [
              _NumberSticker(
                number: 2,
                fg: colors.accent,
                wash: colors.accentWash,
              ),
              const SizedBox(width: AppSpacing.x8),
              Text(
                '아기 배 찜질팩',
                style: texts.caption.copyWith(
                  color: colors.ink700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 16, color: colors.ink300),
            ],
          ),
        ],
      ),
    );
  }
}

/// ③ "배앓이 병원 신호" 칩 — 장면이 안착해 있는 동안 토마토색(coral) 점이 숨쉰다.
class OnboardingAlertChip extends StatefulWidget {
  const OnboardingAlertChip({required this.active, super.key});

  final bool active;

  @override
  State<OnboardingAlertChip> createState() => _OnboardingAlertChipState();
}

class _OnboardingAlertChipState extends State<OnboardingAlertChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(OnboardingAlertChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _start();
    if (!widget.active && oldWidget.active) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  void _start() {
    if (!mounted || context.reduceMotion) return;
    _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return OnboardingFloatSurface(
      borderRadius: AppRadius.brFull,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x12,
        AppSpacing.x8,
        AppSpacing.x16,
        AppSpacing.x8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 20,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final v = _pulse.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 + v * 1.4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.coral.withValues(alpha: 0.4 * (1 - v)),
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.coral,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          Text(
            '배앓이',
            style: texts.caption.copyWith(
              color: colors.ink900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          Text('병원 신호', style: texts.caption.copyWith(color: colors.ink500)),
          const SizedBox(width: AppSpacing.x8),
          _NumberSticker(number: 4, fg: colors.coral, wash: colors.coralWash),
        ],
      ),
    );
  }
}

/// ③ 응급 카드 미리보기 — 상세 '병원 신호' 장의 `EmergencyCard` 축약판.
/// 장면이 안착하면 신호 두 줄이 차례로 내려앉고, 병원 찾기 버튼이 톡 튀어 오른다.
class OnboardingSignalCard extends StatefulWidget {
  const OnboardingSignalCard({required this.active, super.key});

  final bool active;

  @override
  State<OnboardingSignalCard> createState() => _OnboardingSignalCardState();
}

class _OnboardingSignalCardState extends State<OnboardingSignalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _seq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _seq.value = 1;
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(OnboardingSignalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  void _play() {
    if (!mounted || context.reduceMotion) return;
    _seq.forward(from: 0);
  }

  @override
  void dispose() {
    _seq.dispose();
    super.dispose();
  }

  /// 전체 시퀀스 중 [begin]~[end] 구간에서 위에서 살짝 떨어지며 나타난다.
  Widget _drop(double begin, double end, Widget child) {
    return AnimatedBuilder(
      animation: _seq,
      child: child,
      builder: (context, child) {
        final v = Interval(begin, end).transform(_seq.value);
        final eased = Curves.easeOutBack.transform(v);
        return Opacity(
          opacity: const Interval(0, 0.5).transform(v),
          child: Transform.translate(
            offset: Offset(0, -8 * (1 - eased)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    final button = AnimatedBuilder(
      animation: _seq,
      builder: (context, child) {
        final v = const Interval(0.62, 1).transform(_seq.value);
        return Transform.scale(
          scale: 0.86 + 0.14 * Curves.easeOutBack.transform(v),
          child: Opacity(
            opacity: const Interval(0, 0.4).transform(v),
            child: child,
          ),
        );
      },
      // 젤리 버튼 — coral 알약 + 클레이 광택 + 자기 색 그림자.
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          gradient: ClaySheen.gradient(context, colors.coral),
          borderRadius: AppRadius.brFull,
          boxShadow: ClaySheen.toneShadow(context, colors.coral),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 14,
              color: colors.paperRaised,
            ),
            const SizedBox(width: AppSpacing.x4),
            Text(
              '가까운 병원 찾기',
              style: texts.caption.copyWith(
                color: colors.paperRaised,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    return OnboardingFloatSurface(
      width: 206,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 병원 신호 = coralWash 버블 + coral 글자(응급 의미 유지, DESIGN v3 §6).
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.coralWash,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  size: 15,
                  color: colors.coral,
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Flexible(
                child: Text(
                  '이럴 땐 병원에',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: _jua(texts.bodyL).copyWith(color: colors.coral),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          _drop(0.1, 0.45, const _SignalRow(label: '축 처지고 잘 먹지 않아요')),
          const SizedBox(height: AppSpacing.x4),
          _drop(0.3, 0.65, const _SignalRow(label: '숨쉬기 힘들어 보여요')),
          const SizedBox(height: AppSpacing.x8),
          button,
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors.coral,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: context.texts.caption.copyWith(
              color: colors.ink700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// 주아체로 바꾼 [base] — 숫자·카드 제목용(DESIGN v3 §3.3: 모노·가짜 볼드 금지,
/// 한 가지 굵기라 fontWeight는 기본으로 되돌린다).
TextStyle _jua(TextStyle base) => base.copyWith(
  fontFamily: AppFontFamily.display,
  fontFamilyFallback: AppFontFamily.displayFallback,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
);

/// 숫자 스티커 — 순위 배지(제품 섹션 톤 사다리 1 amber · 2 accent)·신호 개수 공용.
/// 동그란 스티커 문법(wash 면 + 흰 테두리 + e1, 주아체 숫자, DESIGN v3 §5.4).
class _NumberSticker extends StatelessWidget {
  const _NumberSticker({
    required this.number,
    required this.fg,
    required this.wash,
  });

  final int number;
  final Color fg;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: wash,
        shape: BoxShape.circle,
        border: Border.all(color: colors.paperRaised, width: 1.5),
        boxShadow: context.shadows.e1,
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      // 상자에 맞춰 줄인다(크기 리터럴 없이).
      child: FittedBox(
        child: Text(
          '$number',
          style: _jua(context.texts.label).copyWith(color: fg),
        ),
      ),
    );
  }
}

/// 썸네일 쿠션 — 동그란 톤 워시 위에 클레이 일러스트를 올린다(DESIGN v3 §4).
class _WashCushion extends StatelessWidget {
  const _WashCushion({
    required this.size,
    required this.wash,
    required this.child,
  });

  final double size;
  final Color wash;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
      child: child,
    );
  }
}

class _RoundGlyph extends StatelessWidget {
  const _RoundGlyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colors.accentWash,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: colors.accent),
    );
  }
}
