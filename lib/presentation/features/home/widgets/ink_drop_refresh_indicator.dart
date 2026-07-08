import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:flutter/cupertino.dart';

/// §10.2 Pull-to-refresh: 수묵 잉크 드롭이 번지는 커스텀 인디케이터("잉크 원 확장").
///
/// [CupertinoSliverRefreshControl]의 `builder`에서 호출한다. 당김 정도에 따라
/// 잉크 원이 커지고, 새로고침 중에는 잉크가 번지는 리플이 반복된다.
/// reduce-motion 시 리플 반복 없이 정적 원으로 대체한다.
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
        width: 44,
        height: 44,
        child: AnimatedBuilder(
          animation: _ripple,
          builder: (context, _) {
            return CustomPaint(
              painter: _InkDropPainter(
                progress: progress,
                rippleT: _spinning ? _ripple.value : 0,
                spinning: _spinning,
                accent: colors.accent,
                wash: colors.accentWash,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InkDropPainter extends CustomPainter {
  _InkDropPainter({
    required this.progress,
    required this.rippleT,
    required this.spinning,
    required this.accent,
    required this.wash,
  });

  final double progress;
  final double rippleT;
  final bool spinning;
  final Color accent;
  final Color wash;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // 당김에 따라 커지는 코어 반경(6 → 16).
    final coreRadius = 6 + progress * 10;

    // 번지는 잉크 워시 배경(코어보다 약간 큼).
    canvas.drawCircle(
      center,
      coreRadius + 4,
      Paint()..color = wash.withValues(alpha: 0.35 + 0.35 * progress),
    );

    // 코어 잉크 원.
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()..color = accent.withValues(alpha: 0.85),
    );

    // armed/refresh 시 잉크가 번지는 리플 링(확장하며 페이드아웃).
    if (spinning) {
      final rippleRadius = coreRadius + rippleT * 14;
      final rippleAlpha = (1 - rippleT).clamp(0.0, 1.0) * 0.6;
      canvas.drawCircle(
        center,
        rippleRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: rippleAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(_InkDropPainter old) =>
      old.progress != progress ||
      old.rippleT != rippleT ||
      old.spinning != spinning ||
      old.accent != accent ||
      old.wash != wash;
}
