import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/theme.dart';

/// §11.0 하단 탭바 (DESIGN v2 — 플로팅 페이퍼 독 + 모핑 잉크 알약).
///
/// 화면 하단에 붙지 않고 좌우 `x16`·하단 `x12`만큼 떠 있는 **독**(paperRaised
/// 바탕 + `line` 헤어라인 보더 + 오버레이 음영 `e4`, 스타디움 라운드)이다. 상단
/// 헤어라인 시그니처는 독 전체를 두르는 보더가 승계한다(그라디언트·블러 없음 —
/// 페이퍼잉크 계약).
///
/// 활성 탭은 `accentWash` 알약이 아이콘에서 라벨 방향으로 **펼쳐지며**(morph)
/// 아이콘/라벨이 `accent`로 물든다(spring, reduce-motion 시 0ms·linear). 비활성은
/// 라벨 없이 외곽선 아이콘 단독(`ink500`)이라, 시각 라벨이 없는 상태의 스크린리더
/// 접근성은 `Semantics` 라벨로 보강한다.
///
/// 탭 시 `selectionClick` 햅틱. 큰 시스템 글자에서 라벨은 배율 상한(1.3)+FittedBox
/// scaleDown으로 방어한다. 탭 전환 페이지 fade-through는 셸(app_router)이 담당한다.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItemData> _items = <_NavItemData>[
    _NavItemData(label: '홈', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItemData(
      label: '기록',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
    ),
    _NavItemData(
      label: '내 정보',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x16,
          0,
          AppSpacing.x16,
          AppSpacing.x12,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x8),
          decoration: BoxDecoration(
            color: c.paperRaised,
            borderRadius: AppRadius.brFull,
            border: Border.all(color: c.line),
            boxShadow: context.shadows.e4,
          ),
          // 아이템 시각 높이 x48로 Row를 고정 → 독 총 높이 48+패딩16 = 64. (없으면
          // 아이템의 Center가 세로로 늘어나 bottomNavigationBar 슬롯 전체를 채워
          // 본문이 0높이로 눌리며 오버플로가 난다.)
          child: SizedBox(
            height: AppSpacing.x48,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      data: _items[i],
                      selected: i == currentIndex,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  /// DESIGN v2 알약 치수. 비활성 시 아이콘(24)+좌우 패딩(12·12)=48로 최소 탭 타깃 충족.
  static const double _pillHeight = AppSpacing.x48; // 48
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // 시각 라벨이 비활성 시 사라지므로 스크린리더용 라벨/상태는 Semantics로 보강한다.
    // excludeSemantics로 GestureDetector 의미론이 가려지므로 onTap도 여기 연결한다.
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
        child: Center(
          child: TweenAnimationBuilder<double>(
            // end만 지정 — 첫 빌드에선 애니메이션 없이 target에 안착하고, 선택이 바뀔
            // 때만 재생된다(불필요한 초기 모션 방지).
            tween: Tween<double>(end: selected ? 1.0 : 0.0),
            duration: AppMotion.resolve(context, AppMotion.base),
            curve: AppMotion.resolveCurve(context, AppMotion.spring),
            builder: (context, raw, _) {
              // 색·알파용은 clamp(spring 오버슈트/역재생 방어), 라벨 폭 리빌용 wf는
              // 음수만 차단(0 초과 오버슈트는 그대로 둬 자연스러운 펼침 유지).
              final tc = raw.clamp(0.0, 1.0);
              final wf = math.max(0.0, raw);
              return Container(
                height: _pillHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
                decoration: BoxDecoration(
                  color: c.accentWash.withValues(alpha: tc),
                  borderRadius: AppRadius.brFull,
                  // 다크모드에서 accentWash 알약이 paperRaised와 거의 겹쳐 흐릿해지므로
                  // accent 톤 헤어라인(브랜드 시그니처)으로 활성 가독성을 보강한다.
                  border: Border.all(
                    color: c.accent.withValues(alpha: tc * 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? data.activeIcon : data.icon,
                      size: _iconSize,
                      // 비활성 아이콘은 라벨 없이 단독이라 ink300보다 진한 ink500 사용.
                      color: Color.lerp(c.ink500, c.accent, tc),
                    ),
                    // 라벨이 아이콘 오른쪽으로 "펼쳐지는" 모핑. 아이콘·라벨 간격(x8)을
                    // 리빌 영역 안에 둬서 비활성 시 폭이 완전히 0이 되게 한다.
                    // 완전 접힘(tc==0) 상태에선 Offstage로 라벨을 무대 밖에 두어
                    // 서브트리는 유지하되(재확장 시 재생성 없음) 시맨틱/파인더에서
                    // 빠지게 한다 — 비활성 시각 라벨의 접근성은 상위 Semantics가 담당.
                    Flexible(
                      child: Offstage(
                        offstage: tc == 0,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: wf,
                            heightFactor: 1,
                            child: Opacity(
                              opacity: tc,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.x8,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    data.label,
                                    style: context.texts.caption.copyWith(
                                      color: c.accent,
                                    ),
                                    maxLines: 1,
                                    // 큰 시스템 글자에서도 알약이 과도하게 늘지 않도록
                                    // 배율 상한을 둔다(하단 탭 관례).
                                    textScaler: MediaQuery.textScalerOf(
                                      context,
                                    ).clamp(maxScaleFactor: 1.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
