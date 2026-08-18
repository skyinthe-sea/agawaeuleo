import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// 스크롤에 따라 자식을 아주 조금 세로로 흘리는 패럴랙스(사진 프레임 안쪽 전용).
///
/// 위젯 중심이 뷰포트 아래쪽에 있을수록 자식을 위로, 위쪽으로 올라갈수록 아래로
/// 밀어(±[maxOffset]) 사진이 프레임 안에서 살짝 미끄러지게 만든다. 소비처는
/// **자식을 프레임보다 크게 그려 클리핑**해야 가장자리에 빈틈이 생기지 않는다
/// (`ProductThumbnail` 참조).
///
/// 스크롤 프레임마다 `setState` 하지 않고 [ValueNotifier] → [Transform.translate]
/// 만 갱신하므로 레이아웃 재계산이 없다. reduce-motion(§9.7)이면 구독 없이
/// [child]를 그대로 반환한다.
class ScrollParallax extends StatefulWidget {
  const ScrollParallax({
    required this.child,
    required this.maxOffset,
    super.key,
  });

  final Widget child;

  /// 최대 이동량(dp). 프레임 크기의 5~8% 정도가 자연스럽다.
  final double maxOffset;

  @override
  State<ScrollParallax> createState() => _ScrollParallaxState();
}

class _ScrollParallaxState extends State<ScrollParallax> {
  final ValueNotifier<double> _shift = ValueNotifier<double>(0);
  ScrollPosition? _position;

  /// 정규화 기준 화면 높이(스크롤 콜백에서 MediaQuery를 뒤지지 않도록 캐시).
  double _screenHeight = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight = MediaQuery.sizeOf(context).height;
    if (AppMotion.reduceMotion(context)) {
      _detach();
      return;
    }
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _position)) return;
    _detach();
    _position = position?..addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _detach() {
    _position?.removeListener(_update);
    _position = null;
  }

  void _update() {
    if (!mounted) return;
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached || !render.hasSize) return;
    if (_screenHeight <= 0) return;

    final center = render.localToGlobal(Offset(0, render.size.height / 2)).dy;
    // 화면 상단 -1 … 하단 +1로 정규화한 뒤 반대 방향으로 흘린다.
    final t = ((center / _screenHeight) - 0.5).clamp(-0.5, 0.5) * 2;
    final next = -t * widget.maxOffset;
    // 0.1dp 미만 변화는 무시(불필요한 리페인트 억제).
    if ((next - _shift.value).abs() < 0.1) return;
    _shift.value = next;
  }

  @override
  void dispose() {
    _detach();
    _shift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;
    return ValueListenableBuilder<double>(
      valueListenable: _shift,
      child: widget.child,
      builder: (context, shift, child) =>
          Transform.translate(offset: Offset(0, shift), child: child),
    );
  }
}
