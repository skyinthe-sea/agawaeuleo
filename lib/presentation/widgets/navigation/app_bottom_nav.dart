import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/theme.dart';

/// §11.0 하단 탭바. 높이 64 + 세이프에어리어, 배경 `paper.raised`, 상단 헤어라인 `line`,
/// 아이콘 28 / 라벨 caption 12, 활성 `accent` / 비활성 `ink.300`.
/// 탭 시 `selectionClick` 햅틱 + 아이콘/라벨 색 트윈 200ms(탭 전환 fade-through는 셸이 담당).
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
          height: 64,
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = selected ? c.accent : c.ink300;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<Color?>(
        duration: AppMotion.resolve(context, const Duration(milliseconds: 200)),
        curve: AppMotion.standard,
        tween: ColorTween(end: target),
        builder: (context, color, _) {
          final resolved = color ?? target;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? data.activeIcon : data.icon,
                size: 28,
                color: resolved,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                data.label,
                style: AppTypography.caption.copyWith(color: resolved),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
