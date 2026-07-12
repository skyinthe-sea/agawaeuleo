import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/theme.dart';

/// §11.0 하단 탭바 (DESIGN v2 재설계 — 활성 잉크워시 알약 인디케이터).
///
/// 배경 `paper.raised` + 상단 헤어라인 `line`(브랜드 시그니처 유지). 활성 탭은 아이콘
/// 뒤에 스타디움형 `accentWash` 알약(먹빛 워시)이 팝인하고 아이콘/라벨이 `accent`로
/// 물든다. 비활성은 외곽선 아이콘 `ink.300` + 라벨 `ink.500`. 알약 톤은 홈 카드
/// 일러스트의 청록 잉크(accent)와 같은 계열이라 홈과 결이 맞는다.
///
/// 탭 시 `selectionClick` 햅틱 + 알약/색 전환 `base`(260ms, reduce-motion 시 0ms).
/// 탭 전환 페이지 fade-through는 셸(app_router)이 담당한다.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paperRaised,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.x64,
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

  /// DESIGN v2 §5.3 활성 인디케이터(스타디움 알약)와 아이콘 치수.
  static const double _pillWidth = AppSpacing.x64; // 64
  static const double _pillHeight = AppSpacing.x32; // 32
  static const double _iconSize = 24;

  /// 팝인 시 알약이 시작하는 스케일(→ 1.0으로 자라며 등장).
  static const double _pillScaleMin = 0.8;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = selected ? 1.0 : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        // end만 지정 — 첫 빌드에선 애니메이션 없이 target에 안착하고, 선택이 바뀔 때만
        // 재생된다(불필요한 초기 모션 방지).
        tween: Tween<double>(end: target),
        duration: AppMotion.resolve(context, AppMotion.base),
        curve: AppMotion.standard,
        builder: (context, raw, _) {
          final t = raw.clamp(0.0, 1.0);
          final iconColor = Color.lerp(c.ink300, c.accent, t)!;
          final labelColor = Color.lerp(c.ink500, c.accent, t)!;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: _pillWidth,
                height: _pillHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 활성 잉크워시 알약 — 스케일 팝인 + 알파 페이드(그림자·그라디언트 없음).
                    Transform.scale(
                      scale: _pillScaleMin + (1 - _pillScaleMin) * t,
                      child: Container(
                        width: _pillWidth,
                        height: _pillHeight,
                        decoration: BoxDecoration(
                          color: c.accentWash.withValues(alpha: t),
                          borderRadius: AppRadius.brFull,
                          // 다크모드에서 accentWash 알약이 paperRaised와 거의 겹쳐
                          // 흐릿해지므로, accent 톤 헤어라인(브랜드 시그니처)으로
                          // 활성 상태 가독성을 보강한다(그림자·그라디언트 금지 준수).
                          border: Border.all(
                            color: c.accent.withValues(alpha: t * 0.22),
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      selected ? data.activeIcon : data.icon,
                      size: _iconSize,
                      color: iconColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              Text(
                data.label,
                style: context.texts.caption.copyWith(color: labelColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // 큰 시스템 글자 크기에서 라벨이 세로로 넘쳐 64dp 탭바를 초과하지
                // 않도록 배율 상한을 둔다(하단 탭 관례).
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3),
              ),
            ],
          );
        },
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
