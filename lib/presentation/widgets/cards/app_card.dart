import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';
import '../surfaces/paper_background.dart';

/// 카드 위계 3단(DESIGN v3 §5.1 "몽글 클레이"). 기본값은 [flat].
///
/// 면 구분은 헤어라인이 아니라 **부드럽게 퍼지는 장밋빛 그림자**가 맡는다 — 세 단
/// 모두 라디우스 `lg`(26)의 말랑한 점토 표면이다.
enum AppCardEmphasis {
  /// 정지 카드(그리드·정보·리스트 카드) — `paperCard` + e1, 보더 없음.
  flat,

  /// 강조·상승 표면 — `paperRaised` + e2.
  raised,

  /// [raised]보다 한 단 더 뜬 `paperRaised` + e3 면 뒤에 **파스텔 톤 wash 아랫장**
  /// ([AppCard.stackColor], 기본 `accentWash`)이 살짝 비어져 나와 "겹쳐 빚은 점토"
  /// 인상을 낸다(요약·BEST 같은 히어로 모먼트 전용 — 그리드 밀도상 남용 금지).
  hero,
}

/// §11.0 카드 — DESIGN v3 §5.1 "몽글 클레이" 표면.
///
/// 라디우스 `lg` · 내부 패딩 16 · [emphasis]별 면/그림자(flat=paperCard+e1,
/// raised=paperRaised+e2, hero=paperRaised+e3+파스텔 아랫장). 헤어라인은 기본적으로
/// 걷어냈고(라이트), 장밋빛 그림자가 약한 다크에서만 `line` 1px로 윤곽을 받친다.
/// [showBorder]를 `true`로 주면 모드와 무관하게 `line` 1.5 윤곽을 그린다.
///
/// [onTap] 지정 시 말랑한 눌림(scale .96) + 오목 그림자 + 딸기 워시 리플.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.emphasis = AppCardEmphasis.flat,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.color,
    this.borderRadius,
    this.showBorder,
    this.clipContent = false,
    this.stackColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 카드 위계(DESIGN v3 §5.1). 기본 `flat`.
  final AppCardEmphasis emphasis;
  final EdgeInsetsGeometry padding;
  final Color? color;

  /// 미지정 시 `brLg`(세 단 공통, DESIGN v3 §3.4 "카드 = lg").
  final BorderRadius? borderRadius;

  /// 윤곽선. `null`(기본)=자동(라이트 없음 · 다크 `line` 1px), `true`=`line` 1.5
  /// 상시, `false`=없음.
  final bool? showBorder;

  /// 자식을 카드 모서리로 클리핑할지(썸네일 등).
  final bool clipContent;

  /// [AppCardEmphasis.hero] 아랫장 색(미지정 시 `accentWash`). 카드가 속한 톤의
  /// wash(버터·민트·라일락…)를 넘기면 그 파스텔이 카드 밑으로 비어져 나온다.
  final Color? stackColor;

  /// [emphasis]의 기본 배경색.
  Color _defaultColor(AppColors colors) => switch (emphasis) {
    AppCardEmphasis.flat => colors.paperCard,
    AppCardEmphasis.raised || AppCardEmphasis.hero => colors.paperRaised,
  };

  /// [emphasis]의 기본 라디우스(v3 — 세 단 모두 lg).
  BorderRadius _defaultRadius() => AppRadius.brLg;

  /// [emphasis]의 기본 음영.
  List<BoxShadow> _defaultShadow(AppShadows shadows) => switch (emphasis) {
    AppCardEmphasis.flat => shadows.e1,
    AppCardEmphasis.raised => shadows.e2,
    AppCardEmphasis.hero => shadows.e3,
  };

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  /// 포인터 다운 지점 — "누른 채 스크롤" 감지용(이동 슬롭 초과 시 눌림 해제).
  Offset? _pointerDownPosition;

  bool get _tappable => widget.onTap != null || widget.onLongPress != null;

  @override
  void deactivate() {
    // 슬리버 이동/재부모화로 서브트리가 비활성화되면 InkWell의
    // onHighlightChanged(false) 콜백이 유실될 수 있다 — 눌림 시각(오목 그림자·
    // 축소)이 고착되지 않도록 직접 초기화한다(재삽입 시 새 값으로 빌드됨).
    _pressed = false;
    super.deactivate();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    AppHaptics.tap();
    widget.onTap?.call();
  }

  /// 카드 윤곽(DESIGN v3 §5.1 — 헤어라인은 되도록 제거).
  ///
  /// 라이트는 장밋빛 그림자가 면을 띄우므로 윤곽이 없다. 다크는 근검정 드롭만으로는
  /// 면 경계가 흐려 `line` 1px을 받친다. [AppCard.showBorder]가 `true`면
  /// 모드와 무관하게 `line` 1.5(§5.1 "필요 시 line 1.5").
  ///
  /// 윤곽은 반드시 균일색 [Border.all]로만 그린다 — 한 변만 다른 색(예: 다크 상단
  /// 하이라이트)을 주면 `Border` 가 비균일색이 되어 [AppCard.borderRadius] 와 함께
  /// 칠할 때 `Border.paint()` assert("A borderRadius can only be given on borders
  /// with uniform colors")가 페인트 도중 터지고 자식이 렌더되지 않는다.
  Border? _cardBorder(BuildContext context) {
    final explicit = widget.showBorder;
    if (explicit == false) return null;
    if (explicit == true) {
      return Border.all(color: context.colors.line, width: 1.5);
    }
    return context.isDark ? Border.all(color: context.colors.line) : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;
    final Color surface = widget.color ?? widget._defaultColor(colors);
    final BorderRadius radius = widget.borderRadius ?? widget._defaultRadius();
    final List<BoxShadow> baseShadow = widget._defaultShadow(shadows);
    final Border? border = _cardBorder(context);

    final bool grain = widget.emphasis == AppCardEmphasis.hero;
    final core = _buildCore(
      context: context,
      colors: colors,
      shadows: shadows,
      surface: surface,
      radius: radius,
      baseShadow: baseShadow,
      border: border,
      grain: grain,
    );

    if (!grain) return core;

    // DESIGN v3 §5.1 hero — 카드 뒤 파스텔 톤 wash 아랫장(좌우 12dp 인셋, 아래로
    // 6dp 비어져 나옴, 동일 라디우스, 보더 없음) + 무광 점토 결(그레인) 오버레이.
    //
    // 그레인은 core "내부"(데코레이션 클립 안)에서 그린다 — core를 ClipRRect로
    // 감싸면 데코레이션이 칠하는 e3 그림자까지 잘려 나가 부양감이 사라진다.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 12,
          right: 12,
          top: 6,
          bottom: -6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.stackColor ?? colors.accentWash,
              borderRadius: radius,
            ),
          ),
        ),
        core,
      ],
    );
  }

  /// [grain]이면 [child] 아래에 무광 점토 결 오버레이를 깐다(§5.1 hero 전용).
  Widget _withGrain(bool grain, Widget child) =>
      grain ? PaperBackground(child: child) : child;

  Widget _buildCore({
    required BuildContext context,
    required AppColors colors,
    required AppShadows shadows,
    required Color surface,
    required BorderRadius radius,
    required List<BoxShadow> baseShadow,
    required Border? border,
    required bool grain,
  }) {
    if (!_tappable) {
      // grain 시 패딩을 자식 쪽으로 옮겨 그레인이 카드 면 전체를 덮게 하고,
      // 데코레이션 클립(자식에만 적용, 그림자는 무사)으로 모서리를 정리한다.
      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          boxShadow: baseShadow,
          border: border,
        ),
        clipBehavior: (grain || widget.clipContent)
            ? Clip.antiAlias
            : Clip.none,
        padding: grain ? null : widget.padding,
        child: grain
            ? PaperBackground(
                child: Padding(padding: widget.padding, child: widget.child),
              )
            : widget.child,
      );
    }

    final reduce = context.reduceMotion;
    final scale = (!reduce && _pressed) ? 0.96 : 1.0;

    // 눌림 해제 안전망(§9.5). InkWell.onHighlightChanged(false)는 부모 스크롤이
    // 제스처 아레나를 가져가는 "누른 채 스크롤" 시퀀스에서 유실될 수 있어, 화면에
    // 남은 카드가 눌린 채 어둡게 고착된다(실기기 재현). Listener는 아레나 밖에서
    // 물리 포인터 수명을 관측하므로, 드래그가 슬롭을 넘으면 즉시(스크롤 시작 시점)
    // 눌림을 풀고, 손을 떼거나 취소되면 반드시 초기화한다 — deactivate() 방어가
    // 못 잡는 "온스크린 잔류" 경로를 덮는다.
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
      child: AnimatedScale(
        scale: scale,
        duration: _pressed ? AppMotion.instant : AppMotion.base,
        curve: _pressed ? AppMotion.standard : AppMotion.spring,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: radius,
            // 눌림 시 부양감 제거 — 오목함은 아래 foregroundDecoration으로 표현.
            boxShadow: _pressed ? AppShadows.e0 : baseShadow,
            border: border,
          ),
          // §9.5 press 오목: 인셋 그림자를 자식 위(foregroundDecoration)에 덧그려야
          // 실제로 보인다. boxShadow(fill 뒤)로는 불투명 배경에 가려 무효과.
          foregroundDecoration: _pressed
              ? BoxDecoration(borderRadius: radius, boxShadow: shadows.press)
              : null,
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            // grain은 Material 클립 안(그림자 밖)에서 그린다. 그레인 레이어는
            // IgnorePointer라 InkWell 탭/리플에 영향 없음.
            child: _withGrain(
              grain,
              InkWell(
                splashFactory: InkWashSplash.splashFactory,
                splashColor: colors.accentWash,
                highlightColor: Colors.transparent,
                borderRadius: radius,
                onTap: _handleTap,
                onLongPress: widget.onLongPress,
                onHighlightChanged: _setPressed,
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
