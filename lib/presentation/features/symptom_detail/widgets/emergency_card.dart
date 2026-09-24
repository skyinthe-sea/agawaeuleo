import 'dart:math' as math;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/external_launcher.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/detail_clay.dart';
import 'package:agawaeuleo/presentation/widgets/animated/shake.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/material.dart';

/// §11.9-3 응급 경고 카드.
///
/// DESIGN v3 "몽글 클레이" — `coralWash` 둥근 카드(lg) + coral 글자·아이콘(응급의
/// 유일한 색), 제목 옆 클레이 버블 아이콘, 좌측 안쪽의 둥근 coral 알약 바.
/// 제목 "이럴 땐 병원에", 본문 응급신호 + "가까운 병원 찾기" 젤리 알약 버튼(지도/전화 외부).
/// 등장 시 1회 미세 흔들림 + 좌측 바 펄스 2회(§10.2, opacity .5↔1 ×2).
class EmergencyCard extends StatefulWidget {
  const EmergencyCard({required this.signs, super.key, this.active = true});

  final List<EmergencySign> signs;

  /// 등장 연출(흔들림·바 펄스)을 재생해도 되는지. 케어 노트처럼 미리 빌드되는
  /// 대기 장에서는 `false`로 두었다가 장이 화면에 들어올 때 `true`로 바꾸면 그때
  /// 1회 재생한다.
  final bool active;

  @override
  State<EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<EmergencyCard>
    with SingleTickerProviderStateMixin {
  // 좌측 바 펄스 컨트롤러(2회 왕복). 등장 시 1회 재생.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Shake 킷의 트리거. 등장 후 1회만 값이 바뀌어 흔들림을 1회 재생한다.
  int _shakeTrigger = 0;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(EmergencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  void _play() {
    if (_played || !mounted || AppMotion.reduceMotion(context)) return;
    _played = true;
    _pulse.forward(from: 0);
    setState(() => _shakeTrigger = 1);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // opacity .5↔1 ×2: 두 번의 왕복(0→1 구간에서 코사인 2주기).
  double _barOpacity(double t) => 0.75 + 0.25 * math.cos(2 * math.pi * 2 * t);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    // 클립 없이 둥근 면만 칠한다 — 바가 안쪽으로 떠 있어 모서리 밖으로 새는
    // 것이 없고, 그림자(카드·버튼)가 잘리지 않는다.
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.coralWash,
        borderRadius: AppRadius.brLg,
        boxShadow: context.shadows.e1,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좌측 둥근 알약 바(안쪽으로 띄움) — 펄스 대상.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x12,
                AppSpacing.x20,
                0,
                AppSpacing.x20,
              ),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: colors.coral.withValues(
                      alpha: _barOpacity(_pulse.value),
                    ),
                    borderRadius: AppRadius.brFull,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x12,
                  AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
                  AppSpacing.x8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClayBubble(
                          size: 38,
                          wash: colors.paperRaised,
                          icon: Icons.local_hospital_rounded,
                          iconColor: colors.coral,
                          iconSize: 20,
                          lifted: true,
                        ),
                        const SizedBox(width: AppSpacing.x12),
                        Expanded(
                          child: Text(
                            '이럴 땐 병원에',
                            style: texts.heading.copyWith(color: colors.coral),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x16),
                    for (final sign in widget.signs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x12),
                        child: _EmergencyItem(sign: sign),
                      ),
                    const SizedBox(height: AppSpacing.x4),
                    const _HospitalButton(),
                    const SizedBox(height: AppSpacing.x4),
                    Center(
                      child: _DialButton(
                        label: '급할 땐 119에 전화하기',
                        onTap: () => ExternalLauncher.dial('119'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Shake(trigger: _shakeTrigger, child: card);
  }
}

class _EmergencyItem extends StatelessWidget {
  const _EmergencyItem({required this.sign});

  final EmergencySign sign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 동그란 coral 점(흰 스티커 테두리).
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colors.coral,
              shape: BoxShape.circle,
              border: Border.all(color: colors.paperRaised, width: 2),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.iconTextGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sign.sign, style: texts.body.copyWith(color: colors.ink900)),
              const SizedBox(height: AppSpacing.x2),
              Text(
                sign.action,
                style: texts.caption.copyWith(
                  color: colors.coral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// coral 배경 "가까운 병원 찾기" 버튼. 탭 스프링 + 라이트 햅틱(§10.1).
class _HospitalButton extends StatefulWidget {
  const _HospitalButton();

  @override
  State<_HospitalButton> createState() => _HospitalButtonState();
}

class _HospitalButtonState extends State<_HospitalButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  Future<void> _handleTap() async {
    AppHaptics.tap();
    await ExternalLauncher.openNearbyHospitals();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;
    final scale = (!reduce && _pressed) ? 0.97 : 1.0;
    // 광택 아래 가운데에서도 paperRaised 글자 4.5:1 이상.
    final fill = DetailTone.fill(context, colors.coral);

    return Semantics(
      button: true,
      label: '가까운 병원 찾기',
      onTap: _handleTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _handleTap,
          child: AnimatedScale(
            scale: scale,
            duration: _pressed ? AppMotion.instant : AppMotion.base,
            curve: _pressed ? AppMotion.standard : AppMotion.spring,
            // coral 젤리 알약 + 클레이 광택 + 톤 그림자. 눌리면 한 톤 깊어지고
            // 그림자가 걷힌다.
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: ClaySheen.gradient(
                  context,
                  _pressed ? Color.lerp(fill, colors.ink900, 0.12)! : fill,
                ),
                borderRadius: AppRadius.brFull,
                boxShadow: _pressed
                    ? AppShadows.e0
                    : ClaySheen.toneShadow(context, fill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: colors.paperRaised,
                  ),
                  const SizedBox(width: AppSpacing.iconTextGap),
                  Text(
                    '가까운 병원 찾기',
                    style: texts.label.copyWith(color: colors.paperRaised),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// coral 텍스트 전화 버튼(보조 액션). 탭 스프링 + 라이트 햅틱. 누르는 자리 48.
class _DialButton extends StatelessWidget {
  const _DialButton({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_rounded, size: 16, color: colors.coral),
              const SizedBox(width: AppSpacing.x4),
              Flexible(
                child: Text(
                  label,
                  style: texts.label.copyWith(color: colors.coral),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
