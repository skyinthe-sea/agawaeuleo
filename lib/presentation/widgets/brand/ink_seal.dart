import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/theme.dart';
import '../surfaces/clay_sheen.dart';

/// 브랜드 오브제 — DESIGN v3 §5.4 **딸기 스티커 도장**(v2 §4.1 낙관 도장의 후신).
///
/// 형태: 말랑한 스퀴클(`ContinuousRectangleBorder`) + `colors.seal`(딸기 핑크) 면에
/// 클레이 광택([ClaySheen.gradient]) + **흰 스티커 테두리**(`paperRaised`, 2dp —
/// 소형은 1.5dp) + e1 음영 + 중앙 글리프 "아"(주아체, `size * 0.52`, `paperRaised`).
/// 기본 -3도 기울기([tilt]로 끌 수 있음) — 손으로 붙인 스티커 인상.
///
/// [animate]가 true면 등장 시 opacity 0→1(fast) + scale 1.4→1.0(base, `curve.enter`)
/// + rotate -6°→-3°로 "탁 붙이는" 스탬프 모션을 재생하고, 완료 시(옵션 [haptic])
/// mediumImpact 햅틱을 울린다. reduce-motion 시에는 스케일/회전 없이 페이드만 재생한다.
///
/// [watermark]가 true면 `sealWash` 면 + `seal` 글리프(테두리·음영 없음)로 뒤집혀 낮은
/// 존재감의 장식용 워터마크가 된다(설정>정보, 약관 뷰어 말미 등).
class InkSeal extends StatefulWidget {
  const InkSeal({
    super.key,
    this.size = sizeMd,
    this.tilt = true,
    this.animate = false,
    this.watermark = false,
    this.haptic = false,
    this.glyph = '아',
  });

  /// 크기 프리셋 — 소형(20dp).
  const InkSeal.sm({
    Key? key,
    bool tilt = true,
    bool animate = false,
    bool watermark = false,
    bool haptic = false,
    String glyph = '아',
  }) : this(
         key: key,
         size: sizeSm,
         tilt: tilt,
         animate: animate,
         watermark: watermark,
         haptic: haptic,
         glyph: glyph,
       );

  /// 크기 프리셋 — 중형(28dp).
  const InkSeal.md({
    Key? key,
    bool tilt = true,
    bool animate = false,
    bool watermark = false,
    bool haptic = false,
    String glyph = '아',
  }) : this(
         key: key,
         size: sizeMd,
         tilt: tilt,
         animate: animate,
         watermark: watermark,
         haptic: haptic,
         glyph: glyph,
       );

  /// 크기 프리셋 — 대형(44dp).
  const InkSeal.lg({
    Key? key,
    bool tilt = true,
    bool animate = false,
    bool watermark = false,
    bool haptic = false,
    String glyph = '아',
  }) : this(
         key: key,
         size: sizeLg,
         tilt: tilt,
         animate: animate,
         watermark: watermark,
         haptic: haptic,
         glyph: glyph,
       );

  static const double sizeSm = 20;
  static const double sizeMd = 28;
  static const double sizeLg = 44;

  final double size;

  /// 손으로 붙인 인상의 기본 -3도 기울기. false면 수평.
  final bool tilt;

  /// true면 스탬프인(stamp-in) 등장 모션 재생(마운트 1회).
  final bool animate;

  /// true면 낮은 존재감의 워터마크 배색(면 `sealWash` / 글리프 `seal`).
  final bool watermark;

  /// 스탬프 모션 완료 시 mediumImpact 햅틱을 울릴지([animate]가 true일 때만 의미).
  final bool haptic;

  /// 중앙 글리프 문자.
  final String glyph;

  @override
  State<InkSeal> createState() => _InkSealState();
}

class _InkSealState extends State<InkSeal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.addStatusListener(_handleStatus);
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    } else {
      _controller.value = 1;
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.haptic && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _play() {
    if (!mounted) return;
    _controller
      ..duration = AppMotion.resolve(context, AppMotion.base)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _restAngleDeg => widget.tilt ? -3 : 0;

  @override
  Widget build(BuildContext context) {
    final sealBox = _SealBox(
      size: widget.size,
      glyph: widget.glyph,
      watermark: widget.watermark,
    );

    if (!widget.animate) {
      return Transform.rotate(
        angle: _restAngleDeg * math.pi / 180,
        child: sealBox,
      );
    }

    final reduce = context.reduceMotion;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        if (reduce) {
          // reduce-motion: 스케일/회전 없이 페이드만.
          return Opacity(
            opacity: t,
            child: Transform.rotate(
              angle: _restAngleDeg * math.pi / 180,
              child: child,
            ),
          );
        }
        final opacity = const Interval(
          0,
          0.69, // ≈ fast(180ms) / base(260ms) — opacity가 base 구간 앞부분에서 완료.
          curve: Curves.linear,
        ).transform(t);
        final eased = AppMotion.enter.transform(t);
        final scale = 1.4 - 0.4 * eased;
        final beginDeg = widget.tilt ? -6.0 : -3.0;
        final angleDeg = beginDeg + (_restAngleDeg - beginDeg) * eased;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: angleDeg * math.pi / 180,
              child: child,
            ),
          ),
        );
      },
      child: sealBox,
    );
  }
}

class _SealBox extends StatelessWidget {
  const _SealBox({
    required this.size,
    required this.glyph,
    required this.watermark,
  });

  final double size;
  final String glyph;
  final bool watermark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glyphColor = watermark ? colors.seal : colors.paperRaised;
    // 연속 곡률 스퀴클 — 같은 라디우스의 RRect보다 모서리가 부드럽게 흘러 점토처럼
    // 말랑해 보인다. ContinuousRectangleBorder의 반경 r은 원호 반경 약 0.43r로 읽히므로
    // 0.72 × size ≈ 원호 0.3 × size(v2 낙관 0.24보다 한 단계 통통하게).
    final radius = BorderRadius.circular(size * 0.72);
    final outline = size <= InkSeal.sizeSm ? 1.5 : 2.0;

    final Decoration decoration = watermark
        ? ShapeDecoration(
            color: colors.sealWash,
            shape: ContinuousRectangleBorder(borderRadius: radius),
          )
        : ShapeDecoration(
            gradient: ClaySheen.gradient(context, colors.seal),
            shape: ContinuousRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: colors.paperRaised, width: outline),
            ),
            shadows: context.shadows.e1,
          );

    final content = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        glyph,
        textScaler: TextScaler.noScaling,
        style: context.texts.title.copyWith(
          fontSize: size * 0.52,
          height: 1,
          letterSpacing: 0,
          color: glyphColor,
        ),
      ),
    );

    return watermark ? Opacity(opacity: 0.7, child: content) : content;
  }
}
