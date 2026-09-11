import 'dart:math' as math;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/external_launcher.dart';
import 'package:agawaeuleo/presentation/widgets/animated/shake.dart';
import 'package:flutter/material.dart';

/// §11.9-3 응급 경고 카드.
///
/// 배경 `coral.wash`, 좌측 4dp 바 `coral`(radius 0), 아이콘 `coral`,
/// 제목 "이럴 땐 병원에", 본문 응급신호 + "가까운 병원 찾기" 버튼(지도/전화 외부).
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

    final card = ClipRRect(
      borderRadius: AppRadius.brMd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.coralWash,
          boxShadow: context.shadows.e1,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 좌측 4dp 바(radius 0) — 펄스 대상.
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => SizedBox(
                  width: 4,
                  child: ColoredBox(
                    color: colors.coral.withValues(
                      alpha: _barOpacity(_pulse.value),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital_rounded,
                            size: 20,
                            color: colors.coral,
                          ),
                          const SizedBox(width: AppSpacing.iconTextGap),
                          Text(
                            '이럴 땐 병원에',
                            style: texts.heading.copyWith(color: colors.ink900),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x12),
                      for (final sign in widget.signs)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.x12,
                          ),
                          child: _EmergencyItem(sign: sign),
                        ),
                      const _HospitalButton(),
                      const SizedBox(height: AppSpacing.x8),
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
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(Icons.fiber_manual_record, size: 6, color: colors.coral),
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
                style: texts.caption.copyWith(color: colors.coral),
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
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.coral,
                borderRadius: AppRadius.brSm,
                boxShadow: _pressed
                    ? context.shadows.press
                    : context.shadows.e2,
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

/// coral 텍스트 전화 버튼(보조 액션). 탭 스프링 + 라이트 햅틱.
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_rounded, size: 16, color: colors.coral),
            const SizedBox(width: AppSpacing.x4),
            Text(label, style: texts.label.copyWith(color: colors.coral)),
          ],
        ),
      ),
    );
  }
}
