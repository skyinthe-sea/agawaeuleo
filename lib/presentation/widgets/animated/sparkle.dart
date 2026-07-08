import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';

/// §10.2 즐겨찾기(별) 반짝임 강조. 별 scale 1→1.3→1 + 작은 반짝이 회전 페이드아웃(420ms).
/// 비활성→활성 전환 시 재생하고 lightImpact를 발생한다. reduce-motion 시 아이콘만 토글.
class Sparkle extends StatefulWidget {
  const Sparkle({
    required this.isActive,
    super.key,
    this.onChanged,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.sparkleColor,
  });

  final bool isActive;

  /// 탭 시 토글된 목표 값을 전달(호출부가 상태를 소유).
  final ValueChanged<bool>? onChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? sparkleColor;

  @override
  State<Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<Sparkle> with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 420);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  @override
  void didUpdateWidget(Sparkle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _burst();
  }

  void _burst() {
    if (!mounted || AppMotion.reduceMotion(context)) return;
    _controller.forward(from: 0);
  }

  void _handleTap() {
    AppHaptics.tap();
    widget.onChanged?.call(!widget.isActive);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = widget.activeColor ?? colors.amber;
    final inactive = widget.inactiveColor ?? colors.ink300;
    final sparkle = widget.sparkleColor ?? active;
    final box = widget.size * 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: box,
        height: box,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final scale = _scaleFor(t);
            return Stack(
              alignment: Alignment.center,
              children: [
                if (t > 0 && t < 1)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SparkPainter(progress: t, color: sparkle),
                    ),
                  ),
                Transform.scale(
                  scale: scale,
                  child: Icon(
                    widget.isActive
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: widget.size,
                    color: widget.isActive ? active : inactive,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 1 → 1.3 → 1 펄스. easeOutBack로 복귀부에 살짝 오버슈트.
  double _scaleFor(double t) {
    if (t <= 0 || t >= 1) return 1;
    if (t < 0.5) {
      return 1 + 0.3 * Curves.easeOut.transform(t / 0.5);
    }
    return 1 + 0.3 * (1 - Curves.easeOutBack.transform((t - 0.5) / 0.5));
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;
  static const int _count = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final eased = Curves.easeOutBack.transform(progress.clamp(0, 1));
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, size.shortestSide * 0.04);

    final rotation = progress * math.pi * 0.6;
    final inner = maxR * 0.45 * eased;
    final outer = maxR * (0.62 + 0.28 * eased);

    for (var i = 0; i < _count; i++) {
      final angle = rotation + i * (2 * math.pi / _count);
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + dir * inner, center + dir * outer, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.progress != progress || old.color != color;
}
