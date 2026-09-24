import 'dart:math' as math;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/cupertino.dart';

/// §10.2 Pull-to-refresh 커스텀 인디케이터.
///
/// DESIGN v3 "몽글 클레이" — v2의 수묵 잉크 드롭을 **딸기 하트**로 바꿨다(이름은 역사적
/// 이름으로 유지). 당길수록 워시 쿠션 위의 하트가 통통하게 커지고, 새로고침 중에는
/// 하트가 두 번씩 콩닥 뛰며 워시 링이 퍼진다(메커니즘은 v2 잉크 드롭 그대로).
/// reduce-motion 시 박동·링 반복 없이 정적 하트로 대체한다.
///
/// [CupertinoSliverRefreshControl]의 `builder`에서 호출한다.
class InkDropRefreshIndicator extends StatefulWidget {
  const InkDropRefreshIndicator({
    required this.mode,
    required this.pulledExtent,
    required this.triggerDistance,
    super.key,
  });

  final RefreshIndicatorMode mode;
  final double pulledExtent;
  final double triggerDistance;

  @override
  State<InkDropRefreshIndicator> createState() =>
      _InkDropRefreshIndicatorState();
}

class _InkDropRefreshIndicatorState extends State<InkDropRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool get _spinning =>
      widget.mode == RefreshIndicatorMode.refresh ||
      widget.mode == RefreshIndicatorMode.armed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncRipple();
    });
  }

  @override
  void didUpdateWidget(InkDropRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRipple();
  }

  void _syncRipple() {
    final wantRipple = _spinning && !context.reduceMotion;
    if (wantRipple && !_ripple.isAnimating) {
      _ripple.repeat();
    } else if (!wantRipple && _ripple.isAnimating) {
      _ripple
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = widget.triggerDistance <= 0
        ? 0.0
        : (widget.pulledExtent / widget.triggerDistance).clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: AnimatedBuilder(
          animation: _ripple,
          builder: (context, _) {
            return CustomPaint(
              painter: _HeartDropPainter(
                progress: progress,
                beatT: _spinning ? _ripple.value : 0,
                spinning: _spinning,
                heart: colors.seal,
                ring: colors.accent,
                wash: colors.accentWash,
                shine: ClaySheen.light(context),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeartDropPainter extends CustomPainter {
  _HeartDropPainter({
    required this.progress,
    required this.beatT,
    required this.spinning,
    required this.heart,
    required this.ring,
    required this.wash,
    required this.shine,
  });

  final double progress;
  final double beatT;
  final bool spinning;
  final Color heart;
  final Color ring;
  final Color wash;
  final Color shine;

  /// 한 주기 안에서 두 번 콩닥(0 → 1 → 0, 두 번째는 조금 약하게).
  static double _beat(double t) {
    double pulse(double center, double width) {
      final d = (t - center).abs() / width;
      return d >= 1 ? 0 : math.cos(d * math.pi / 2);
    }

    return math.max(pulse(0.12, 0.12), pulse(0.38, 0.12) * 0.7);
  }

  /// 단위 상자(0..1) 안의 통통한 하트 — 두 볼록한 윗봉우리 + 둥근 아래 꼭지.
  static Path _heartPath(Offset center, double size) {
    Offset p(double x, double y) =>
        center + Offset((x - 0.5) * size, (y - 0.49) * size);
    final a = p(0.5, 0.92);
    final path = Path()..moveTo(a.dx, a.dy);
    void cubic(Offset c1, Offset c2, Offset to) =>
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, to.dx, to.dy);
    cubic(p(0.26, 0.76), p(0.04, 0.58), p(0.04, 0.36));
    cubic(p(0.04, 0.18), p(0.17, 0.06), p(0.31, 0.06));
    cubic(p(0.41, 0.06), p(0.47, 0.12), p(0.5, 0.2));
    cubic(p(0.53, 0.12), p(0.59, 0.06), p(0.69, 0.06));
    cubic(p(0.83, 0.06), p(0.96, 0.18), p(0.96, 0.36));
    cubic(p(0.96, 0.58), p(0.74, 0.76), a);
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final beat = spinning ? _beat(beatT) : 0.0;
    // 당김에 따라 커지는 하트 크기(12 → 26) + 박동.
    final heartSize = (12 + progress * 14) * (1 + 0.14 * beat);

    // 폭신한 워시 쿠션(하트보다 조금 큼).
    canvas.drawCircle(
      center,
      heartSize * 0.5 + 6,
      Paint()..color = wash.withValues(alpha: 0.45 + 0.45 * progress),
    );

    // armed/refresh — 하트에서 퍼지는 링(확장하며 페이드아웃).
    if (spinning) {
      final ringRadius = heartSize * 0.5 + 6 + beatT * 12;
      final ringAlpha = (1 - beatT).clamp(0.0, 1.0) * 0.5;
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring.withValues(alpha: ringAlpha),
      );
    }

    // 딸기 하트 + 왼쪽 위 봉우리의 작은 광택(점토 윗면에 빛이 닿은 정도).
    canvas
      ..drawPath(
        _heartPath(center, heartSize),
        Paint()..color = heart.withValues(alpha: 0.6 + 0.4 * progress),
      )
      ..drawCircle(
        center + Offset(-heartSize * 0.2, -heartSize * 0.17),
        heartSize * 0.07,
        Paint()..color = shine.withValues(alpha: 0.7 * progress),
      );
  }

  @override
  bool shouldRepaint(_HeartDropPainter old) =>
      old.progress != progress ||
      old.beatT != beatT ||
      old.spinning != spinning ||
      old.heart != heart ||
      old.ring != ring ||
      old.wash != wash ||
      old.shine != shine;
}
