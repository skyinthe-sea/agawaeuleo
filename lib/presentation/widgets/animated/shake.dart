import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/theme.dart';

/// §10.2 흔들기(에러 등). hz 4 · offset 3dp · 400ms. 트리거형 — [trigger] 값이 바뀔 때
/// 1회 재생. reduce-motion 시 재생하지 않는다(정지 = 단순화).
class Shake extends StatefulWidget {
  const Shake({
    required this.child,
    super.key,
    this.trigger,
    this.hz = 4,
    this.offset = const Offset(3, 0),
    this.duration = AppMotion.slow,
  });

  final Widget child;

  /// 이 값이 이전 빌드와 달라지면 흔들기를 1회 재생한다.
  final Object? trigger;
  final double hz;
  final Offset offset;
  final Duration duration;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _fire();
  }

  void _fire() {
    if (!mounted || AppMotion.reduceMotion(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child
        .animate(controller: _controller, autoPlay: false)
        .shake(
          hz: widget.hz,
          offset: widget.offset,
          rotation: 0,
          duration: widget.duration,
          curve: AppMotion.standard,
        );
  }
}
