import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// §11.0 상단바 — DESIGN v3 "몽글 클레이".
///
/// 높이 56, 배경은 화면과 같은 딸기우유 크림(`paperBg`)이라 평상시엔 바가 화면에
/// 녹아든다(헤어라인 없음). 스크롤 시(`scrolled: true`)에만 장밋빛 음영 e2가 올라
/// 콘텐츠 위로 떠 보인다. 제목은 좌측 정렬 주아체 `title`(22), 뒤로가기는 `paperRaised`
/// 동그란 점토 버블(40, e1) 안의 둥근 화살표 — 히트 영역은 48.
///
/// [scrolled] 는 화면이 스크롤 오프셋을 감지해 전달한다. [subtitle]을 지정하면
/// 타이틀 아래 2dp에 caption(ink500) 슬롯이 추가된다.
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
                icon: Icons.arrow_back_rounded,
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
              style: context.texts.title.copyWith(color: c.ink900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.x2),
          Text(
            subtitle!,
            style: context.texts.caption.copyWith(color: c.ink500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paperBg,
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
                // 동그란 뒤로 버블과 주아체 제목 사이 숨 쉴 틈.
                const SizedBox(width: AppSpacing.x8),
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

  static const double _bubble = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // §2-3 최소 터치타깃 48dp — 버블(40)은 보이는 면, 히트 영역은 48 폭 전체.
        child: SizedBox(
          width: 48,
          height: AppAppBar._height,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.paperRaised,
                shape: BoxShape.circle,
                boxShadow: context.shadows.e1,
              ),
              child: SizedBox.square(
                dimension: _bubble,
                child: Icon(icon, size: 22, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
