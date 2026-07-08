import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 상단 인사 영역(스크롤 시 스크롤아웃).
///
/// 좌측: 인사 title(명조 22) 또는 아기 이름. 우측: 알림 벨 아이콘(24) +
/// 안읽음 배지 dot(`coral`). 배경은 페이지 배경과 동일하게 두어 스크롤아웃될 때
/// 자연스럽게 사라진다.
class HomeGreetingBar extends StatelessWidget {
  const HomeGreetingBar({
    required this.greeting,
    required this.onBellTap,
    this.hasUnread = true,
    super.key,
  });

  /// 표시할 인사 문구(아기 이름이 있으면 이름, 없으면 기본 인사).
  final String greeting;
  final VoidCallback onBellTap;

  /// 벨 배지 dot 표시 여부.
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.x12,
        AppSpacing.x8,
        AppSpacing.x8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              greeting,
              style: context.texts.title.copyWith(color: colors.ink900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _BellButton(
            hasUnread: hasUnread,
            onTap: onBellTap,
            color: colors.ink700,
            dotColor: colors.coral,
            raised: colors.paperBg,
          ),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({
    required this.hasUnread,
    required this.onTap,
    required this.color,
    required this.dotColor,
    required this.raised,
  });

  final bool hasUnread;
  final VoidCallback onTap;
  final Color color;
  final Color dotColor;

  /// dot 테두리 색(배경과 대비를 위한 얇은 링).
  final Color raised;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hasUnread ? '알림, 새 소식 있음' : '알림',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, size: 24, color: color),
              if (hasUnread)
                Positioned(
                  top: 11,
                  right: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: raised, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
