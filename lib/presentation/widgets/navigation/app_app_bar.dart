import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// §11.0 상단바. 높이 56, 배경 `paper.raised`, 좌측 정렬 명조 title(22),
/// 뒤로가기 아이콘 24 · 좌측 패딩 16. DESIGN v2 §5.2 — `scrolled` 여부와 무관하게
/// 하단 헤어라인 `line`을 상시 표시하고, 스크롤 시(`scrolled: true`)에는 e2를
/// 추가로 올린다(2단 표면 문법).
///
/// [scrolled] 는 화면이 스크롤 오프셋을 감지해 전달한다(false=헤어라인만,
/// true=헤어라인+e2). [subtitle]을 지정하면 타이틀 아래 2dp에 caption(ink500)
/// 슬롯이 추가된다.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    this.title,
    this.titleWidget,
    this.subtitle,
    this.showBack,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.scrolled = false,
    super.key,
  });

  final String? title;
  final Widget? titleWidget;

  /// 타이틀 아래 2dp 보조 슬롯(caption, ink500). [titleWidget] 지정 시에도 함께 쓸 수 있다.
  final String? subtitle;

  /// null=자동(Navigator.canPop). true/false 로 강제 지정.
  final bool? showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget> actions;
  final bool scrolled;

  static const double _height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canPop = showBack ?? Navigator.of(context).canPop();
    final leadingWidget =
        leading ??
        (canPop
            ? _AppBarButton(
                icon: Icons.arrow_back,
                color: c.ink900,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null);

    final titleColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleWidget ??
            Text(
              title ?? '',
              style: AppTypography.title.copyWith(color: c.ink900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.x2),
          Text(
            subtitle!,
            style: AppTypography.caption.copyWith(color: c.ink500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paperRaised,
        border: Border(bottom: BorderSide(color: c.line)),
        boxShadow: scrolled ? context.shadows.e2 : null,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              if (leadingWidget != null) ...[
                const SizedBox(width: AppSpacing.x8),
                leadingWidget,
              ] else
                const SizedBox(width: AppSpacing.x16),
              Expanded(child: titleColumn),
              if (actions.isNotEmpty) ...[
                ...actions,
                const SizedBox(width: AppSpacing.x8),
              ] else
                const SizedBox(width: AppSpacing.x16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // §2-3 최소 터치타깃 48dp(아이콘 24는 유지, 히트 영역 폭만 40→48).
      child: SizedBox(
        width: 48,
        height: AppAppBar._height,
        child: Center(child: Icon(icon, size: 24, color: color)),
      ),
    );
  }
}
