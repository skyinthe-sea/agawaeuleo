import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/theme.dart';

/// §11.0 하단 탭바 (DESIGN v2.3 — 먹 캡슐, 2026-09-11).
///
/// 화면 폭을 가로지르던 독 대신, 가운데에 떠 있는 **작은 캡슐**(paperRaised +
/// `line` 헤어라인 + 오버레이 음영 `e4`)이다. 탭이 둘뿐이라 넓은 독은 휑했고, 홈 덱
/// 아래 레일과도 무게가 겹쳤다.
///
/// 활성 표시는 `ink900` 먹 알약이다. 탭을 바꾸면 알약이 **먹이 번지듯** 흐른다 —
/// 가는 방향의 앞 가장자리가 먼저 뻗고 뒤 가장자리가 늦게 따라와 잠깐 늘어났다가
/// 새 칸에 맞춰 앉는다. 칸 줄을 두 겹(먹색 바탕 / 알약 모양으로 자른 종이색·채운
/// 아이콘)으로 그려, 알약 가장자리가 지나가는 자리에서 글자가 정확히 뒤집힌다.
/// 다크 모드는 `ink900`이 밝은 먹이라 알약·글자 대비가 자동으로 뒤집힌다.
/// 그라데이션·블러 없음(페이퍼잉크 계약).
///
/// 두 탭 모두 라벨을 늘 보여 준다(아이콘 단독의 모호함 제거). 탭 시 `selectionClick`
/// 햅틱, 칸 높이 48(최소 터치 타깃), 큰 시스템 글자는 배율 상한 1.3 + FittedBox
/// 축소로 방어, reduce-motion이면 알약이 즉시 옮겨 앉는다. 탭 전환 페이지
/// fade-through는 셸(app_router)이 담당한다.
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 탭 순서 = 셸 브랜치 순서(app_router). 항목을 되살리면 브랜치도 함께 되살릴 것.
  static const List<_NavItemData> _items = <_NavItemData>[
    _NavItemData(label: '홈', icon: Icons.home_outlined, activeIcon: Icons.home),
    // 기록 기능 숨김(2026-09-11 발주자 요청 — 제품 추천 집중). 삭제가 아니라 주석:
    // 되살릴 때는 이 항목과 app_router.dart의 기록 브랜치 주석을 함께 해제한다.
    // _NavItemData(
    //   label: '기록',
    //   icon: Icons.assignment_outlined,
    //   activeIcon: Icons.assignment,
    // ),
    _NavItemData(
      label: '내 정보',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  /// 칸 한 개의 폭·높이와 캡슐 안쪽 여백.
  static const double _cellWidth = 112;
  static const double _cellHeight = AppSpacing.x48;
  static const double _inset = AppSpacing.x4;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  /// 먹 알약이 흐르는 시간 — 앞 가장자리는 이 중 앞부분에, 뒤 가장자리는 늦게 끝난다.
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  /// 흐름 시작 시점의 알약 좌·우 가장자리(칸 단위 — 칸 i는 [i, i+1]).
  late double _fromLeft = widget.currentIndex.toDouble();
  late double _fromRight = widget.currentIndex + 1.0;

  static const Curve _leadCurve = Interval(0, 0.62, curve: Curves.easeOutCubic);
  static const Curve _trailCurve = Interval(
    0.18,
    1,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    // 흐르는 도중에 또 바뀌어도 지금 보이는 자리에서 이어서 흐른다.
    final (left, right) = _edges(oldWidget.currentIndex);
    _fromLeft = left;
    _fromRight = right;
    if (AppMotion.reduceMotion(context)) {
      _flow.value = 1;
    } else {
      _flow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  /// 현재 알약 좌·우 가장자리(칸 단위). [previousTarget]은 흐름의 목적지 계산용.
  (double, double) _edges([int? previousTarget]) {
    final target = previousTarget ?? widget.currentIndex;
    final t = _flow.value;
    final toLeft = target.toDouble();
    final toRight = target + 1.0;
    final movingRight = toLeft >= _fromLeft;
    // 가는 방향의 가장자리가 앞장선다.
    final leftT = (movingRight ? _trailCurve : _leadCurve).transform(t);
    final rightT = (movingRight ? _leadCurve : _trailCurve).transform(t);
    return (
      lerpDouble(_fromLeft, toLeft, leftT)!,
      lerpDouble(_fromRight, toRight, rightT)!,
    );
  }

  void _select(int index) {
    HapticFeedback.selectionClick();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const items = AppBottomNav._items;
    const cell = AppBottomNav._cellWidth;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x12),
        child: Center(
          heightFactor: 1,
          child: Container(
            padding: const EdgeInsets.all(AppBottomNav._inset),
            decoration: BoxDecoration(
              color: c.paperRaised,
              borderRadius: AppRadius.brFull,
              border: Border.all(color: c.line),
              boxShadow: context.shadows.e4,
            ),
            child: SizedBox(
              width: cell * items.length,
              height: AppBottomNav._cellHeight,
              child: AnimatedBuilder(
                animation: _flow,
                // 두 겹의 칸 줄은 애니메이션과 무관하므로 한 번만 만든다.
                child: _NavRow(
                  items: items,
                  currentIndex: widget.currentIndex,
                  inked: false,
                  onTap: _select,
                ),
                builder: (context, baseRow) {
                  final (left, right) = _edges();
                  final pill = RRect.fromLTRBR(
                    left * cell,
                    0,
                    right * cell,
                    AppBottomNav._cellHeight,
                    const Radius.circular(AppBottomNav._cellHeight / 2),
                  );
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: pill.outerRect,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.ink900,
                            borderRadius: AppRadius.brFull,
                          ),
                        ),
                      ),
                      // 바탕 글자(먹색) — 탭·스크린리더를 맡는다.
                      baseRow!,
                      // 알약 안 글자(종이색·채운 아이콘) — 알약 모양으로 잘라, 먹이
                      // 지나가는 가장자리에서 글자가 정확히 뒤집힌다.
                      IgnorePointer(
                        child: ExcludeSemantics(
                          child: ClipPath(
                            clipper: _PillClipper(pill),
                            child: _NavRow(
                              items: items,
                              currentIndex: widget.currentIndex,
                              inked: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 알약 모양 클리퍼(흐르는 동안 매 프레임 모양이 바뀐다).
class _PillClipper extends CustomClipper<Path> {
  const _PillClipper(this.pill);

  final RRect pill;

  @override
  Path getClip(Size size) => Path()..addRRect(pill);

  @override
  bool shouldReclip(_PillClipper oldClipper) => oldClipper.pill != pill;
}

/// 칸 줄 한 겹. [inked]면 알약 안쪽 모습(종이색 + 채운 아이콘)이다.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.items,
    required this.currentIndex,
    required this.inked,
    this.onTap,
  });

  final List<_NavItemData> items;
  final int currentIndex;
  final bool inked;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          _NavCell(
            data: items[i],
            selected: i == currentIndex,
            inked: inked,
            onTap: onTap == null ? null : () => onTap!(i),
          ),
      ],
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.data,
    required this.selected,
    required this.inked,
    this.onTap,
  });

  final _NavItemData data;
  final bool selected;

  /// 알약 안쪽 겹(종이색 + 채운 아이콘)인지.
  final bool inked;

  /// null이면 장식 겹(탭·시맨틱스 없음).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = inked ? c.paperRaised : c.ink500;

    final content = SizedBox(
      width: AppBottomNav._cellWidth,
      height: AppBottomNav._cellHeight,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  inked ? data.activeIcon : data.icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.x8),
                Text(
                  data.label,
                  maxLines: 1,
                  style: context.texts.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  // 큰 시스템 글자에서도 캡슐이 과도하게 늘지 않도록 상한.
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: data.label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
