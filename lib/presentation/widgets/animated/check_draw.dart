import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// §10.2 기록 완료 체크 드로우. 체크 경로를 300ms에 그려낸다.
/// 마운트 시 자동 재생하며 [trigger] 변경 시 다시 그린다. reduce-motion 시 즉시 완성.
class CheckDraw extends StatefulWidget {
  const CheckDraw({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
    this.duration = const Duration(milliseconds: 300),
    this.trigger,
  });

  final double size;
  final Color? color;
  final double strokeWidth;
  final Duration duration;

  /// 값이 바뀌면 드로우를 재생한다.
  final Object? trigger;

  @override
  State<CheckDraw> createState() => _CheckDrawState();
}

class _CheckDrawState extends State<CheckDraw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void didUpdateWidget(CheckDraw oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _play();
  }

  void _play() {
    if (!mounted) return;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.accent;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _CheckPainter(
            progress: _controller.value,
            color: color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.22, h * 0.52)
      ..lineTo(w * 0.42, h * 0.72)
      ..lineTo(w * 0.78, h * 0.30);

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
