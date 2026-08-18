import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// 뷰포트에 실제로 들어온 순간 **1회** 재생되는 등장 모션
/// (페이드 + 상승 + 스프링 스케일업).
///
/// `SingleChildScrollView` 안의 자식은 화면 밖에 있어도 즉시 build 되므로
/// build 시점에 모션을 걸면, 사용자가 스크롤해 내려왔을 때는 이미 끝나 있다.
/// 이 위젯은 가장 가까운 [Scrollable]의 오프셋을 구독해 **위젯 상단이 화면
/// 아래쪽 [visibleFraction] 지점까지 올라온 프레임**에 재생을 시작하고, 시작
/// 즉시 구독을 해제한다(1회성 — 되감기 없음, 재스크롤 시 반복되지 않는다).
///
/// 진행도(선형 0→1)는 [ScrollRevealScope]로 자손에게 내려간다. 자손은
/// [RevealMotion]으로 **자기 구간만 잘라** 늦게 따라 들어올 수 있다(순위 배지
/// 스탬프, CTA 슬라이드업 등 내부 시퀀싱).
///
/// - reduce-motion(§9.7)이면 구독·모션 없이 [child]를 그대로 반환한다
///   (스코프도 내리지 않으므로 자손의 [RevealMotion]도 함께 정지한다).
/// - [Scrollable] 조상이 없으면(고정 레이아웃) 첫 프레임에 바로 재생한다.
/// - 재생이 끝나면 `Opacity`/`Transform` 레이어를 걷어내고 [child]만 그린다.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.rise = AppSpacing.x24,
    this.scaleFrom = 0.94,
    this.visibleFraction = 0.1,
  });

  final Widget child;

  /// 재생 시작 지연(계단식 등장(stagger)에 사용).
  final Duration delay;

  /// 시작 시 아래로 밀어둘 거리(dp). 0이면 상승 없이 페이드만.
  final double rise;

  /// 시작 스케일(1이면 스케일 없음). 스프링 커브라 끝에서 살짝 넘겼다 앉는다.
  final double scaleFrom;

  /// 위젯 상단이 화면 높이의 `(1 - 이 값)` 지점까지 올라오면 재생한다.
  ///
  /// 너무 작으면 화면 밖에서 시작해 다 끝난 뒤에 보이고(체감 0), 너무 크면
  /// 이미 보일 자리가 한동안 비어 있어 늦게 뜨는 것처럼 보인다. 0.1 전후가
  /// "들어오면서 뜬다"에 해당한다.
  final double visibleFraction;

  /// 카드 자체의 페이즈 — 불투명도/이동/스케일이 각각 이 구간에서 끝난다.
  /// 남은 뒤쪽 구간은 자손([RevealMotion])이 따라 들어올 여유로 남겨 둔다.
  ///
  /// 불투명도를 이동보다 먼저 끝내야 "빠릿하게 떴고, 마지막에 살짝 앉는다"로
  /// 읽힌다. 이 둘을 뒤로 미루면 카드가 늦게 뜨는 인상이 된다.
  static const double _fadeEnd = 0.45;
  static const double _moveEnd = 0.6;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

/// [ScrollReveal]의 선형 진행도(0→1)를 자손에게 내려주는 스코프.
class ScrollRevealScope extends InheritedWidget {
  const ScrollRevealScope({
    required this.progress,
    required super.child,
    super.key,
  });

  /// 커브가 적용되지 않은 **선형** 진행도. 소비처가 [phase]로 잘라 쓴다.
  final Animation<double> progress;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScrollRevealScope>()?.progress;

  /// 전체 진행도 [t]에서 `[begin, end]` 구간만 0→1로 정규화한 뒤 [curve] 적용.
  static double phase(double t, double begin, double end, Curve curve) {
    if (end <= begin) return t >= end ? 1 : 0;
    final normalized = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(normalized);
  }

  @override
  bool updateShouldNotify(ScrollRevealScope oldWidget) =>
      oldWidget.progress != progress;
}

/// [ScrollReveal] 진행도에 얹혀 **자기 구간에서만** 움직이는 자손용 모션.
///
/// 스코프가 없으면(리빌 밖 배치 · reduce-motion) 아무것도 하지 않고 자식을
/// 그대로 그린다.
class RevealMotion extends StatelessWidget {
  const RevealMotion({
    required this.child,
    super.key,
    this.begin = 0,
    this.end = 1,
    this.curve = AppMotion.enter,
    this.scaleFrom = 1,
    this.rise = 0,
    this.fade = false,
  });

  final Widget child;

  /// 전체 진행도(0→1) 중 이 모션이 차지할 구간.
  final double begin;
  final double end;
  final Curve curve;

  /// 시작 스케일(1이면 스케일 없음). 1보다 크면 "찍히듯" 줄며 앉는다.
  final double scaleFrom;

  /// 시작 시 아래로 밀어둘 거리(dp).
  final double rise;

  /// 구간 동안 페이드인할지.
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final progress = ScrollRevealScope.maybeOf(context);
    if (progress == null) return child;

    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final t = ScrollRevealScope.phase(progress.value, begin, end, curve);
        if (t >= 1) return child!;

        var result = child!;
        if (scaleFrom != 1) {
          result = Transform.scale(
            scale: lerpDouble(scaleFrom, 1, t)!,
            child: result,
          );
        }
        if (rise != 0) {
          result = Transform.translate(
            offset: Offset(0, (1 - t) * rise),
            child: result,
          );
        }
        if (fade) {
          result = Opacity(opacity: t.clamp(0.0, 1.0), child: result);
        }
        return result;
      },
    );
  }
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  // reduce-motion에서는 build가 이 컨트롤러를 한 번도 쓰지 않는다. `late` 지연
  // 초기화로 두면 dispose() 시점에야 처음 생성되며 `createTicker`가 이미
  // 비활성화된 엘리먼트의 조상(TickerMode)을 조회해 터진다 → 즉시 만든다.
  late final AnimationController _controller;

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
    // 내부 시퀀싱(배지 스탬프 → CTA)이 따라 들어올 여유까지 포함한 길이.
    // 이보다 늘리면 카드가 "늦게 뜬다"는 인상이 된다(발주자 피드백).
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow * 1.1,
    );
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;

    return ScrollRevealScope(
      progress: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          // 카드 본체가 다 앉은 뒤에도 자손 시퀀싱이 남아 있으므로, 레이어를
          // 걷어내는 조건은 "이동 구간 종료"로 잡는다.
          if (t >= ScrollReveal._moveEnd) return child!;

          final fade = ScrollRevealScope.phase(
            t,
            0,
            ScrollReveal._fadeEnd,
            AppMotion.enter,
          );
          final move = ScrollRevealScope.phase(
            t,
            0,
            ScrollReveal._moveEnd,
            AppMotion.enter,
          );
          // 스프링(easeOutBack)이라 끝에서 1을 살짝 넘겼다가 앉는다.
          final pop = ScrollRevealScope.phase(
            t,
            0,
            ScrollReveal._moveEnd,
            AppMotion.spring,
          );

          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - move) * widget.rise),
              child: Transform.scale(
                scale: lerpDouble(widget.scaleFrom, 1, pop)!,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
