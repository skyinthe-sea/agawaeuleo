import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';

/// §10.1 탭 스프링. 누름 scale 1.0→0.96(100ms), 뗌 0.96→1.0 스프링(easeOutBack 260ms).
/// 자체 Material ink가 없는 임의 탭 요소용 래퍼. reduce-motion 시 스케일 없이 즉시 반응.
class TapSpring extends StatefulWidget {
  const TapSpring({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  /// 탭 시 lightImpact 발생 여부.
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<TapSpring> createState() => _TapSpringState();
}

class _TapSpringState extends State<TapSpring> {
  bool _pressed = false;

  /// 포인터 다운 지점 — "누른 채 스크롤" 감지용(이동 슬롭 초과 시 눌림 해제).
  Offset? _pointerDownPosition;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.haptic) AppHaptics.tap();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    final scale = (!reduce && _pressed) ? widget.pressedScale : 1.0;

    // 눌림 해제 안전망: 부모(가로/세로) 스크롤이 제스처 아레나를 가져가면
    // GestureDetector.onTapCancel이 유실될 수 있어 눌림 시각이 고착된다. Listener는
    // 아레나 밖에서 물리 포인터를 관측하므로, 드래그가 슬롭을 넘으면 즉시 눌림을
    // 풀고, 손을 떼거나 취소되면 반드시 초기화한다.
    return Listener(
      onPointerDown: (event) => _pointerDownPosition = event.position,
      onPointerMove: (event) {
        final down = _pointerDownPosition;
        if (_pressed &&
            down != null &&
            (event.position - down).distance > kTouchSlop) {
          _setPressed(false);
        }
      },
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: scale,
          duration: _pressed ? AppMotion.instant : AppMotion.base,
          curve: _pressed ? AppMotion.standard : AppMotion.spring,
          child: widget.child,
        ),
      ),
    );
  }
}
