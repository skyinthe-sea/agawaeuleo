import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// 뷰포트에 실제로 들어온 순간 **1회** 재생되는 등장 모션
/// (페이드 + 상승 + 미세 스케일업).
///
/// `SingleChildScrollView` 안의 자식은 화면 밖에 있어도 즉시 build 되므로
/// build 시점에 모션을 걸면, 사용자가 스크롤해 내려왔을 때는 이미 끝나 있다.
/// 이 위젯은 가장 가까운 [Scrollable]의 오프셋을 구독해 **위젯 상단이 화면에
/// 걸치는 프레임**에 재생을 시작하고, 시작 즉시 구독을 해제한다(1회성 — 되감기
/// 없음, 재스크롤 시 반복되지 않는다).
///
/// - reduce-motion(§9.7)이면 구독·모션 없이 [child]를 그대로 반환한다.
/// - [Scrollable] 조상이 없으면(고정 레이아웃) 첫 프레임에 바로 재생한다.
/// - 재생이 끝나면 `Opacity`/`Transform` 레이어를 걷어내고 [child]만 그린다.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.rise = AppSpacing.x16,
    this.scaleFrom = 0.97,
    this.visibleFraction = 0.06,
  });

  final Widget child;

  /// 재생 시작 지연(계단식 등장(stagger)에 사용).
  final Duration delay;

  /// 시작 시 아래로 밀어둘 거리(dp). 0이면 상승 없이 페이드만.
  final double rise;

  /// 시작 스케일(1이면 스케일 없음).
  final double scaleFrom;

  /// 화면 높이 대비 이만큼 위로 올라오면 "보였다"로 판정한다(0.06 = 6%).
  final double visibleFraction;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  // reduce-motion에서는 build가 이 둘을 한 번도 쓰지 않는다. `late` 지연 초기화로
  // 두면 dispose() 시점에야 처음 생성되며 `createTicker`가 이미 비활성화된
  // 엘리먼트의 조상(TickerMode)을 조회해 터진다 → initState에서 즉시 만든다.
  late final AnimationController _controller;
  late final CurvedAnimation _progress;

  /// 구독 중인 스크롤 위치(재생 시작 시 해제).
  ScrollPosition? _position;
  Timer? _delayTimer;
  bool _started = false;

  /// 판정 기준이 되는 화면 높이. 스크롤 콜백마다 MediaQuery를 뒤지지 않도록
  /// 의존성 변경 시점(회전·크기 변화 포함)에만 갱신한다.
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _progress = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    // 첫 레이아웃 직후 1회 판정 — 이미 화면 안이면 바로 재생한다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight = MediaQuery.sizeOf(context).height;
    if (_started) return;
    // reduce-motion이면 어차피 build가 child를 그대로 반환하므로 구독하지 않는다.
    if (AppMotion.reduceMotion(context)) {
      _detach();
      return;
    }
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _position)) return;
    _detach();
    _position = position?..addListener(_maybeStart);
  }

  void _detach() {
    _position?.removeListener(_maybeStart);
    _position = null;
  }

  /// 뷰포트 판정 후 재생. 스크롤 프레임마다 호출되므로 계산은 최소로 유지한다.
  void _maybeStart() {
    if (_started || !mounted) return;
    // reduce-motion이면 build가 child를 그대로 반환하므로 컨트롤러/지연 타이머를
    // 아예 만들지 않는다(테스트의 pending timer 검사도 여기서 함께 막힌다).
    if (AppMotion.reduceMotion(context)) return;

    // Scrollable 조상이 없는 배치(고정 레이아웃)면 판정 없이 즉시 재생.
    if (_position != null) {
      final render = context.findRenderObject();
      if (render is! RenderBox || !render.attached || !render.hasSize) return;
      if (_screenHeight <= 0) return;
      final top = render.localToGlobal(Offset.zero).dy;
      if (top > _screenHeight * (1 - widget.visibleFraction)) return;
    }

    _started = true;
    _detach();
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _detach();
    _delayTimer?.cancel();
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;

    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        // 재생 완료 후에는 합성 레이어를 걷어낸다(스크롤 성능).
        if (t >= 1) return child!;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.rise),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
